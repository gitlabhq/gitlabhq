# The database stores locked paths as following:
# 'app/models/user.rb' or 'app/models'
# To determine that 'app/models/user.rb' is locked we need to generate
# tokens for every requested paths and check every token whether it exist in path locks table or not.
# So for 'app/models/user.rb' path we would need to search next paths:
# 'app', 'app/models' and 'app/models/user.rb'
#
# We also need to find downstream locks. As an example for "app" path we would need to
# return "app/models/user.rb" lock.

class Gitlab::PathLocksFinder
  include ActiveRecord::Sanitization::ClassMethods

  def initialize(project)
    @project = project
    @non_locked_paths = []
  end

  def find(path, exact_match: false, downstream: false)
    return unless @project.feature_available?(:file_locks)

    if exact_match
      find_by_token(path)
    else
      # Search upstream locks
      tokenize(path).each do |token|
        if lock = find_by_token(token)
          return lock
        end
      end

      find_downstream(path) if downstream
    end
  end

  private

  # This returns hierarchy tokens for path
  # app/models/project.rb => ['app', 'app/models', 'app/models/project.rb']
  def tokenize(path)
    segments = path.split("/")

    tokens = []
    begin
      tokens << segments.join("/")
      segments.pop
    end until segments.empty?

    tokens
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def find_by_token(token)
    if @non_locked_paths.include?(token)
      return false
    end

    lock = @project.path_locks.find_by(path: token)

    unless lock
      @non_locked_paths << token
    end

    lock
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def find_downstream(path)
    @project.path_locks.find_by("path LIKE ?", "#{sanitize_sql_like(path)}%")
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
