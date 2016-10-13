module BuildsHelper
  def sidebar_build_class(build, current_build)
    build_class = ''
    build_class += ' active' if build == current_build
    build_class += ' retried' if build.retried?
  end
end
