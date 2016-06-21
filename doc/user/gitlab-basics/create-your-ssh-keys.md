# How to create your SSH Keys

You need to connect your computer to your GitLab account through SSH Keys. They are unique for every computer that you link your GitLab account with.

## Generate your SSH Key

Create an account on GitLab. Sign up and check your email for your confirmation link.

After you confirm, go to GitLab and sign in to your account.

## Add your SSH Key

On the left side menu, click on "profile settings" and then click on "SSH Keys":

![SSH Keys](basicsimages/shh_keys.png)

Then click on the green button "Add SSH Key":

![Add SSH Key](basicsimages/add_sshkey.png)

There, you should paste the SSH Key that your command line will generate for you. Below you'll find the steps to generate it:

![Paste SSH Key](basicsimages/paste_sshkey.png)

## To generate an SSH Key on your command line

Go to your [command line](start-using-git.md) and follow the [instructions](../ssh/README.md) to generate it.

Copy the SSH Key that your command line created and paste it on the "Key" box on the GitLab page. The title will be added automatically.

![Paste SSH Key](basicsimages/key.png)

Now, you'll be able to use Git over SSH, instead of Git over HTTP.
