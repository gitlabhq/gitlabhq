# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class FixCrossProjectLabelLinks
      GROUP_NESTED_LEVEL = 10.freeze

      class Project < ActiveRecord::Base
        self.table_name = 'projects'
      end

      class Label < ActiveRecord::Base
        self.inheritance_column = :_type_disabled
        self.table_name = 'labels'
      end

      class LabelLink < ActiveRecord::Base
        self.table_name = 'label_links'
      end

      class Issue < ActiveRecord::Base
        self.table_name = 'issues'
      end

      class MergeRequest < ActiveRecord::Base
        self.table_name = 'merge_requests'
      end

      class Namespace < ActiveRecord::Base
        self.inheritance_column = :_type_disabled
        self.table_name = 'namespaces'

        def self.groups_with_descendants_ids(start_id, stop_id)
          # To isolate migration code, we avoid usage of
          # Gitlab::GroupHierarchy#base_and_descendants which already
          # does this job better
          ids = Namespace.where(type: 'Group', id: Label.where(type: 'GroupLabel').select('distinct group_id')).where(id: start_id..stop_id).pluck(:id)
          group_ids = ids

          GROUP_NESTED_LEVEL.times do
            ids = Namespace.where(type: 'Group', parent_id: ids).pluck(:id)
            break if ids.empty?

            group_ids += ids
          end

          group_ids.uniq
        end
      end

      def perform(start_id, stop_id)
        group_ids = Namespace.groups_with_descendants_ids(start_id, stop_id)
        project_ids = Project.where(namespace_id: group_ids).select(:id)

        fix_issues(project_ids)
        fix_merge_requests(project_ids)
      end

      private

      # select IDs of issues which reference a label which is:
      # a) a project label of a different project, or
      # b) a group label of a different group than issue's project group
      def fix_issues(project_ids)
        issue_ids = Label
          .joins('INNER JOIN label_links ON label_links.label_id = labels.id AND label_links.target_type = \'Issue\'
                  INNER JOIN issues ON issues.id = label_links.target_id
                  INNER JOIN projects ON projects.id = issues.project_id')
          .where('issues.project_id in (?)', project_ids)
          .where('(labels.project_id is not null and labels.project_id != issues.project_id) '\
                 'or (labels.group_id is not null and labels.group_id != projects.namespace_id)')
          .select('distinct issues.id')

        Issue.where(id: issue_ids).find_each { |issue| check_resource_labels(issue, issue.project_id) }
      end

      # select IDs of MRs which reference a label which is:
      # a) a project label of a different project, or
      # b) a group label of a different group than MR's project group
      def fix_merge_requests(project_ids)
        mr_ids = Label
          .joins('INNER JOIN label_links ON label_links.label_id = labels.id AND label_links.target_type = \'MergeRequest\'
                  INNER JOIN merge_requests ON merge_requests.id = label_links.target_id
                  INNER JOIN projects ON projects.id = merge_requests.target_project_id')
          .where('merge_requests.target_project_id in (?)', project_ids)
          .where('(labels.project_id is not null and labels.project_id != merge_requests.target_project_id) '\
                 'or (labels.group_id is not null and labels.group_id != projects.namespace_id)')
          .select('distinct merge_requests.id')

        MergeRequest.where(id: mr_ids).find_each { |merge_request| check_resource_labels(merge_request, merge_request.target_project_id) }
      end

      def check_resource_labels(resource, project_id)
        local_labels = available_labels(project_id)

        # get all label links for the given resource (issue/MR)
        # which reference a label not included in avaiable_labels
        # (other than its project labels and labels of ancestor groups)
        cross_labels = LabelLink
          .select('label_id, labels.title as title, labels.color as color, label_links.id as label_link_id')
          .joins('INNER JOIN labels ON labels.id = label_links.label_id')
          .where(target_type: resource.class.name.demodulize, target_id: resource.id)
          .where('labels.id not in (?)', local_labels.select(:id))

        cross_labels.each do |label|
          matching_label = local_labels.find {|l| l.title == label.title && l.color == label.color}

          next unless matching_label

          Rails.logger.info "#{resource.class.name.demodulize} #{resource.id}: replacing #{label.label_id} with #{matching_label.id}"
          LabelLink.update(label.label_link_id, label_id: matching_label.id)
        end
      end

      # get all labels available for the project (including
      # group labels of ancestor groups)
      def available_labels(project_id)
        @labels ||= {}
        @labels[project_id] ||= Label
          .where("(type = 'GroupLabel' and group_id in (?)) or (type = 'ProjectLabel' and id = ?)",
                 project_group_ids(project_id),
                 project_id)
      end

      def project_group_ids(project_id)
        ids = [Project.find(project_id).namespace_id]

        GROUP_NESTED_LEVEL.times do
          group = Namespace.find(ids.last)
          break unless group.parent_id

          ids << group.parent_id
        end

        ids
      end
    end
  end
end
