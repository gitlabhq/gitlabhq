module UserHelper

  def abuse_report_button_title(user)
    if user.abuse_report
      "#{user.username} has already been reported for abuse."
    else
      "Report #{user.username} for abuse."
    end
  end

end
