# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # This cop checks for `expect(worker).to receive(:perform_async)` usage in specs
      #
      # @example
      #   # bad
      #   it "enqueues a worker" do
      #     expect(MyWorker).to receive(:perform_async)
      #   end
      #
      #   # good
      #   it "enqueues a worker" do
      #     expect(MyWorker).to have_enqueued_sidekiq_job
      #   end
      #
      #   # bad
      #   it "enqueues a worker" do
      #     expect(MyWorker).to receive(:perform_async).with(1, 2)
      #   end
      #
      #   # good
      #   it "enqueues a worker" do
      #     expect(MyWorker).to have_enqueued_sidekiq_job(1, 2)
      #   end
      #
      class HaveEnqueuedSidekiqJob < RuboCop::Cop::Cop
        MESSAGE = 'Do not use `receive(:perform_async)` to check a job has been enqueued, use `have_enqueued_sidekiq_job` instead.'

        def_node_search :expect_to_receive_perform_async?, <<~PATTERN
          (send
            (send nil? :expect ...)
            {:to :not_to :to_not}
            {
              (send nil? :receive (sym :perform_async))

              (send
                (send nil? :receive (sym :perform_async)) ...
              )

              (send
                (send
                  (send nil? :receive (sym :perform_async)) ...
                ) ...
              )
            }
          )
        PATTERN

        def on_send(node)
          return unless expect_to_receive_perform_async?(node)

          add_offense(node, location: :expression, message: MESSAGE)
        end
      end
    end
  end
end
