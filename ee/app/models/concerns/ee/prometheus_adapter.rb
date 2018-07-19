module EE
  module PrometheusAdapter
    extend ::Gitlab::Utils::Override

    def clear_prometheus_reactive_cache!(query_name, *args)
      query_class = query_klass_for(query_name)
      query_args = build_query_args(*args)

      clear_reactive_cache!(query_class.name, *query_args)
    end

    private

    override :build_query_args
    def build_query_args(*args)
      args.map do |arg|
        arg.respond_to?(:id) ? arg.id : arg
      end
    end
  end
end
