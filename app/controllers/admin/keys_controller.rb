class Admin::KeysController < Admin::ApplicationController
  before_action :user, only: [:show, :destroy]

  def show
    @key = user.keys.find(params[:id])

    respond_to do |format|
      format.html
      format.js { head :ok }
    end
  end

  def destroy
    key = user.keys.find(params[:id])

    respond_to do |format|
      if key.destroy
        format.html { redirect_to [:admin, user], notice: '用户密钥删除成功。' }
      else
        format.html { redirect_to [:admin, user], alert: '用户密钥删除失败。' }
      end
    end
  end

  protected

  def user
    @user ||= User.find_by!(username: params[:user_id])
  end

  def key_params
    params.require(:user_id, :id)
  end
end
