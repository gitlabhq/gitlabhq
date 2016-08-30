class Profiles::U2fRegistrationsController < Profiles::ApplicationController
  def destroy
    u2f_registration = current_user.u2f_registrations.find(params[:id])
    u2f_registration.destroy
    redirect_to profile_two_factor_auth_path, notice: "Successfully deleted U2F device."
  end
end
