class ProjectAuthorization < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  validates :project, presence: true
  validates :access_level, inclusion: { in: Gitlab::Access.all_values }, presence: true
  validates :user, uniqueness: { scope: [:project, :access_level] }, presence: true

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
