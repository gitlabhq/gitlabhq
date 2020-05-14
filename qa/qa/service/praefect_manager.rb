# frozen_string_literal: true

module QA
  module Service
    class PraefectManager
      include Service::Shellout

      def initialize
        @praefect = 'praefect'
        @first_node = 'gitaly1'
        @second_node = 'gitaly2'
        @primary_node = @first_node
        @secondary_node = @second_node
      end

      def stop_primary_node
        shell "docker stop #{@primary_node}"
        @secondary_node, @primary_node = @primary_node, @secondary_node
      end

      def reset
        shell "docker start #{@primary_node}"
        shell "docker start #{@secondary_node}"
      end
    end
  end
end
