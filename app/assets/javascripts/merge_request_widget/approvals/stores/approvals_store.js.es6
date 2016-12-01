(() => {
  let singleton;
  const adminUser =
    '{"id":1,"email":"admin@example.com","created_at":"2016-10-17T17:21:34.545Z","updated_at":"2016-12-01T12:40:12.884Z","name":"Administrator","admin":true,"projects_limit":100,"skype":"","linkedin":"","twitter":"","authentication_token":"9PQj4RxcKbyQwG5uAykL","theme_id":2,"bio":"","username":"root","can_create_group":true,"can_create_team":false,"state":"active","color_scheme_id":1,"password_expires_at":null,"created_by_id":null,"last_credential_check_at":null,"avatar":{"url":"/uploads/user/avatar/1/avatar.png"},"hide_no_ssh_key":true,"website_url":"","admin_email_unsubscribed_at":null,"notification_email":"admin@example.com","hide_no_password":false,"password_automatically_set":false,"location":"","encrypted_otp_secret":null,"encrypted_otp_secret_iv":null,"encrypted_otp_secret_salt":null,"otp_required_for_login":false,"otp_backup_codes":null,"public_email":"","dashboard":"projects","project_view":"readme","consumed_timestep":null,"layout":"fixed","hide_project_limit":false,"note":null,"otp_grace_period_started_at":null,"ldap_email":false,"external":false,"organization":"","incoming_email_token":"3rkrn7wdxmeyds49fdmlk7376","authorized_projects_populated":true}';

  class ApprovalsStore {
    constructor(rootEl) {
      if (!singleton) {
        singleton = gl.MergeRequestWidget.ApprovalsStore = this;
        this.init(rootEl);
      }
      return singleton;
    }

    init(rootEl) {
      this.data = {};
      const dataset = rootEl.dataset;
      const approverNames = JSON.parse(dataset.approverNames);
      this.assignToData({
        approvedByUsers: JSON.parse(dataset.approvedByUsers),
        approvalsRequired: Number(dataset.approvalsRequired),
        approverNames,
        approvalsLeft: Number(dataset.approvalsLeft),
        userHasApproved: Boolean(true),
        userCanApprove: Boolean(true),
      });
    }

    assignToData(val) {
      Object.assign(this.data, val);
    }

    /** TODO: remove after backend integerated */
    approve() {
      const approvedByUsers = this.data.approvedByUsers;
      const approverNames = this.data.approverNames;
      const userCanApprove = this.data.userCanApprove;

      const index = approverNames.indexOf("Administrator");

      approverNames.splice(index, 1);
      approvedByUsers.push(JSON.parse(adminUser));

      this.assignToData({
        approverNames,
        approvedByUsers,
        userHasApproved: true,
        userCanApprove: true,
        approvalsLeft: this.data.approvalsLeft -= 1
      });
    }

    unapprove() {
      debugger;
      const approverNames = this.data.approverNames;
      const approvedByUsers = this.data.approvedByUsers;

      approverNames.push("Administrator");
      approvedByUsers.pop(0);

      this.assignToData({
        approverNames,
        approvedByUsers,
        userHasApproved: false,
        userCanApprove: true,
        approvalsLeft: this.data.approvalsLeft += 1
      });
    }

  }
  gl.MergeRequestWidget.ApprovalsStore = ApprovalsStore;
})();

// TODO: Document the weirdness of shared data because of the UI
