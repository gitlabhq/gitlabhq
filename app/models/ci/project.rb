# == Schema Information
#
# Table name: projects
#
#  id                       :integer          not null, primary key
#  name                     :string(255)      not null
#  timeout                  :integer          default(3600), not null
#  created_at               :datetime
#  updated_at               :datetime
#  token                    :string(255)
#  default_ref              :string(255)
#  path                     :string(255)
#  always_build             :boolean          default(FALSE), not null
#  polling_interval         :integer
#  public                   :boolean          default(FALSE), not null
#  ssh_url_to_repo          :string(255)
#  gitlab_id                :integer
#  allow_git_fetch          :boolean          default(TRUE), not null
#  email_recipients         :string(255)      default(""), not null
#  email_add_pusher         :boolean          default(TRUE), not null
#  email_only_broken_builds :boolean          default(TRUE), not null
#  skip_refs                :string(255)
#  coverage_regex           :string(255)
#  shared_runners_enabled   :boolean          default(FALSE)
#  generated_yaml_config    :text
#

module Ci
  class Project < ActiveRecord::Base
    extend Ci::Model

    include Ci::ProjectStatus

    belongs_to :gl_project, class_name: '::Project', foreign_key: :gitlab_id

    has_many :runner_projects, dependent: :destroy, class_name: 'Ci::RunnerProject'
    has_many :runners, through: :runner_projects, class_name: 'Ci::Runner'
    has_many :web_hooks, dependent: :destroy, class_name: 'Ci::WebHook'
    has_many :events, dependent: :destroy, class_name: 'Ci::Event'
    has_many :variables, dependent: :destroy, class_name: 'Ci::Variable'
    has_many :triggers, dependent: :destroy, class_name: 'Ci::Trigger'

    # Project services
    has_many :services, dependent: :destroy, class_name: 'Ci::Service'
    has_one :hip_chat_service, dependent: :destroy, class_name: 'Ci::HipChatService'
    has_one :slack_service, dependent: :destroy, class_name: 'Ci::SlackService'
    has_one :mail_service, dependent: :destroy, class_name: 'Ci::MailService'

    accepts_nested_attributes_for :variables, allow_destroy: true

    delegate :name_with_namespace, :path_with_namespace, :web_url, :http_url_to_repo, :ssh_url_to_repo, to: :gl_project

    #
    # Validations
    #
    validates_presence_of :timeout, :token, :default_ref, :gitlab_id

    validates_uniqueness_of :gitlab_id

    validates :polling_interval,
              presence: true,
              if: ->(project) { project.always_build.present? }

    before_validation :set_default_values

    class << self
      include Ci::CurrentSettings

      def base_build_script
        <<-eos
  git submodule update --init
  ls -la
        eos
      end

      def parse(project)
        params = {
          gitlab_id:                project.id,
          default_ref:              project.default_branch || 'master',
          email_add_pusher:         current_application_settings.add_pusher,
          email_only_broken_builds: current_application_settings.all_broken_builds,
        }

        project = Ci::Project.new(params)
        project.build_missing_services
        project
      end

      def already_added?(project)
        where(gitlab_id: project.id).any?
      end

      def unassigned(runner)
        joins("LEFT JOIN #{Ci::RunnerProject.table_name} ON #{Ci::RunnerProject.table_name}.project_id = #{Ci::Project.table_name}.id " \
          "AND #{Ci::RunnerProject.table_name}.runner_id = #{runner.id}").
        where("#{Ci::RunnerProject.table_name}.project_id" => nil)
      end

      def ordered_by_last_commit_date
        last_commit_subquery = "(SELECT gl_project_id, MAX(committed_at) committed_at FROM #{Ci::Commit.table_name} GROUP BY gl_project_id)"
        joins("LEFT JOIN #{last_commit_subquery} AS last_commit ON #{Ci::Project.table_name}.gitlab_id = last_commit.gl_project_id").
          order("CASE WHEN last_commit.committed_at IS NULL THEN 1 ELSE 0 END, last_commit.committed_at DESC")
      end
    end

    def name
      name_with_namespace
    end

    def path
      path_with_namespace
    end

    def gitlab_url
      web_url
    end

    def any_runners?(&block)
      if runners.active.any?(&block)
        return true
      end

      shared_runners_enabled && Ci::Runner.shared.active.any?(&block)
    end

    def set_default_values
      self.token = SecureRandom.hex(15) if self.token.blank?
      self.default_ref ||= 'master'
    end

    def tracked_refs
      @tracked_refs ||= default_ref.split(",").map { |ref| ref.strip }
    end

    def valid_token? token
      self.token && self.token == token
    end

    def no_running_builds?
      # Get running builds not later than 3 days ago to ignore hangs
      builds.running.where("updated_at > ?", 3.days.ago).empty?
    end

    def email_notification?
      email_add_pusher || email_recipients.present?
    end

    def web_hooks?
      web_hooks.any?
    end

    def services?
      services.any?
    end

    def timeout_in_minutes
      timeout / 60
    end

    def timeout_in_minutes=(value)
      self.timeout = value.to_i * 60
    end

    def coverage_enabled?
      coverage_regex.present?
    end

    # Build a clone-able repo url
    # using http and basic auth
    def repo_url_with_auth
      auth = "gitlab-ci-token:#{token}@"
      http_url_to_repo.sub(/^https?:\/\//) do |prefix|
        prefix + auth
      end
    end

    def available_services_names
      %w(slack mail hip_chat)
    end

    def build_missing_services
      available_services_names.each do |service_name|
        service = services.find { |service| service.to_param == service_name }

        # If service is available but missing in db
        # we should create an instance. Ex `create_gitlab_ci_service`
        self.send :"create_#{service_name}_service" if service.nil?
      end
    end

    def execute_services(data)
      services.each do |service|

        # Call service hook only if it is active
        begin
          service.execute(data) if service.active && service.can_execute?(data)
        rescue => e
          logger.error(e)
        end
      end
    end

    def setup_finished?
      commits.any?
    end

    def commits
      gl_project.ci_commits.ordered
    end

    def builds
      gl_project.ci_builds
    end
  end
end
