class PipelineDecorator < SimpleDelegator
  # It makes clear that this implementation belongs more to
  # Ci::Pipeline than to decorator, but we only do use ordered
  # build in view. It makes sense to refine current implementation
  # to accomadate to this discrepancy and DRY implementation.
  #
  def each_ordered_build
    HasStatus::ORDERED_STATUSES.each do |build_status|
      builds_for_status(build_status).each do |build|
        yield build
      end
    end
  end

  def builds_for_status(build_status)
    builds.order('id DESC').to_a.select do |build|
      build.status == build_status
    end
  end
end
