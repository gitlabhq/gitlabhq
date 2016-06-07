# The database stores locked paths as following:
# 'app/models/project.rb' or 'lib/gitlab'
# To determine that 'lib/gitlab/some_class.rb' is locked we need to generate
# tokens for every requested paths and check every token whether it exist in path locks table or not.
# So for 'lib/gitlab/some_class.rb' path we would need to search next paths:
# 'lib', 'lib/gitlab' and 'lib/gitlab/some_class.rb'
# This class also implements a memoization for common paths like 'lib' 'lib/gitlab', 'app', etc.

class Gitlab::PathLocksFinder
  def initialize(project)
    @project = project
    @non_locked_paths = []
  end

  def get_lock_info(path, exact_match: false)
    if exact_match
      return find_lock(path)
    else
      tokenize(path).each do |token|
        if lock = find_lock(token)
          return lock
        end
      end

      false
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

  def find_lock(token)
    if @non_locked_paths.include?(token)
      return false
    end

    lock = @project.path_locks.find_by(path: token)

    unless lock
      @non_locked_paths << token
    end

    lock
  end
end
