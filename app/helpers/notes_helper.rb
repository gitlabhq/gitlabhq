module NotesHelper
  def loading_more_notes?
    params[:loading_more].present?
  end

  def loading_new_notes?
    params[:loading_new].present?
  end
end
