# frozen_string_literal: true

module Ci
  module BuildTraceChunks
    class Database
      def keys(relation)
        []
      end

      def delete_keys(keys)
        # no-op
      end

      def data(model)
        model.raw_data
      rescue ActiveModel::MissingAttributeError
        model.reset.raw_data
      end

      def set_data(model, new_data)
        model.raw_data = new_data
      end

      def append_data(model, new_data, offset)
        if offset > 0
          truncated_data = data(model).to_s.byteslice(0, offset)
          new_data = truncated_data + new_data
        end

        set_data(model, new_data)
        model.raw_data.to_s.bytesize
      end

      def size(model)
        data(model).to_s.bytesize
      end

      def delete_data(model)
        model.update_columns(raw_data: nil) unless model.raw_data.nil?
      end
    end
  end
end
