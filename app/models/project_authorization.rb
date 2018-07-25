# frozen_string_literal: true

class ProjectAuthorization < ActiveRecord::Base
  prepend ::EE::ProjectAuthorization

  belongs_to :user
  belongs_to :project

  validates :project, presence: true
  validates :access_level, inclusion: { in: Gitlab::Access.all_values }, presence: true
  validates :user, uniqueness: { scope: [:project, :access_level] }, presence: true

  def self.select_from_union(union)
    select(['project_id', 'MAX(access_level) AS access_level'])
      .from("(#{union.to_sql}) #{ProjectAuthorization.table_name}")
      .group(:project_id)
  end

  def self.insert_authorizations(rows, per_batch = 1000)
    rows.each_slice(per_batch) do |slice|
      tuples = slice.map do |tuple|
        tuple.map { |value| connection.quote(value) }
      end

      connection.execute <<-EOF.strip_heredoc
      INSERT INTO project_authorizations (user_id, project_id, access_level)
      VALUES #{tuples.map { |tuple| "(#{tuple.join(', ')})" }.join(', ')}
      EOF
    end
  end
end
