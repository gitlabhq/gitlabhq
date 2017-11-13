module Gitlab
  module Unicorn
    module Hook
      class << self
        attr_writer :before_fork, :after_fork

        def before_fork(&block)
          @before_fork = block
        end

        def after_fork(&block)
          @after_fork = block
        end

        def run_before_fork(server, worker)
          @before_fork.call(server, worker) if @before_fork
        end

        def run_after_fork(server, worker)
          @after_fork.call(server, worker) if @after_fork
        end
      end
    end
  end
end
