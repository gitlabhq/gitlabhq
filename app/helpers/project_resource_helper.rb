module ProjectResourceHelper
  def ref
    flash[:ref] || @ref || @repository.root_ref
  end
end
