# Two-Factor Authentication

## Recovery options

If you lose your code generation device (such as your mobile phone) and you need
to disable two-factor authentication on your account, you have several options.

### Use a saved recovery code

When you enabled two-factor authentication for your account, a series of
recovery codes were generated. If you saved those codes somewhere safe, you
may use one to sign in.

First, enter your username/email and password on the GitLab sign in page. When
prompted for a two-factor code, enter one of the recovery codes you saved
previously.

> **Note:** Once a particular recovery code has been used, it cannot be used again.
  You may still use the other saved recovery codes at a later time.

### Generate new recovery codes using SSH

It's not uncommon for users to forget to save the recovery codes when enabling
two-factor authentication. If you have an SSH key added to your GitLab account,
you can generate a new set of recovery codes using SSH.

Run `ssh git@gitlab.example.com 2fa_recovery_codes`. You will be prompted to
confirm that you wish to generate new codes. If you choose to continue, any
previously saved codes will be invalidated.

```bash
$ ssh git@gitlab.example.com 2fa_recovery_codes
Are you sure you want to generate new two-factor recovery codes?
Any existing recovery codes you saved will be invalidated. (yes/no)
yes

Your two-factor authentication recovery codes are:

119135e5a3ebce8e
11f6v2a498810dcd
3924c7ab2089c902
e79a3398bfe4f224
34bd7b74adbc8861
f061691d5107df1a
169bf32a18e63e7f
b510e7422e81c947
20dbed24c5e74663
df9d3b9403b9c9f0

During sign in, use one of the codes above when prompted for
your two-factor code. Then, visit your Profile Settings and add
a new device so you do not lose access to your account again.
```

Next, go to the GitLab sign in page and enter your username/email and password.
When prompted for a two-factor code, enter one of the recovery codes obtained
from the command line output.

> **Note:** After signing in, you should immediately visit your **Profile Settings
  -> Account** to set up two-factor authentication with a new device.

### Ask a GitLab administrator to disable two-factor on your account

If the above two methods are not possible, you may ask a GitLab global
administrator to disable two-factor authentication for your account. Please
be aware that this will temporarily leave your account in a less secure state.
You should sign in and re-enable two-factor authentication as soon as possible
after the administrator disables it.
