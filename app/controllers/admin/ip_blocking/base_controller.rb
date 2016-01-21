class Admin::IpBlocking::BaseController < Admin::ApplicationController
  before_action :set_row, only: [:index]
  before_action :get_row, only: [:edit, :update, :destroy]

  def index
    @collection = model.all.order('id DESC')
    if params[:search].present?
      @collection = search_in_collection
    end

    @collection = @collection.page(params[:page]).per(30)
  end

  def create
    attrs = row_attributes
    attrs[:user] = current_user

    @row = model.new(attrs)
    if @row.save
      redirect_to index_path, notice: "Added new #{row_type_name}"
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @row.update_attributes(row_attributes)
      redirect_to index_path, notice: "Updated #{row_type_name}"
    else
      render 'edit'
    end
  end

  def destroy
    @row.destroy
    redirect_to index_path, notice: "Removed #{row_type_name}"
  end

  private

  def set_row
    @row = model.new
  end

  def get_row
    @row = model.find(params[:id])
  end

  def search_in_collection
    raise NotImplementedError
  end

  def row_attributes
    raise NotImplementedError
  end

  def row_type_name
    raise NotImplementedError
  end

  def model
    raise NotImplementedError
  end

  def index_path
    raise NotImplementedError
  end

  def form_namespace
    raise NotImplementedError
  end
end
