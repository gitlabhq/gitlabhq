# frozen_string_literal: true

module Git
  module ChangeParams
    private

    %i[oldrev newrev ref].each do |method|
      define_method method do
        change[method]
      end
    end

    def change
      @change ||= params.fetch(:change, {})
    end

    def gitaly_context
      params.fetch(:gitaly_context, {})
    end
  end
end
