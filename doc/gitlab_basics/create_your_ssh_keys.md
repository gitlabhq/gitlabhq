# How to create your SSH Keys

You need to connect your computer to your GitLab account through SSH Keys. They are unique for every computer that you link with your GitLab account with.

## Generate your SSH Key

* Create an account on GitLab. Sign up and check your email for your confirmation link

* After you confirm, go to [gitlab.com](https://about.gitlab.com/) and sign in to your account

## Add your SSH Key

* At the top right corner, click on "profile settings"

![profile settings](basicimages/profile_settings.png)

* On the left side menu click on "SSH Keys"

![SSH Keys](basicimages/shh_keys.png)

* Then click on the green button "Add SSH Key"

![Add SSH Key](basicimages/add_sshkey.png)

* There, you should paste the SSH Key that your commandline will generate for you. Below you'll find the steps to generate it

![Paste SSH Key](basicimages/paste_sshkey.png)

## To generate an SSH Key on your commandline

* Go to your [commandline](start_using_git.md) and follow the [instructions](https://gitlab.com/help/ssh/README) to generate it 

* Copy your SSH Key that your commandline created and paste it on the "Key" box on the GitLab page. The title will be added automatically

![Paste SSH Key](basicimages/key.png)

## Things to know when using your commandline
	
1. Don’t use capital letters 

1. You need to find out how your directory is structured. The structure is like a tree, so you won’t be able to access one subfolder unless you open the main folder where it is contained. Directories are folders or files in your system. 

1. You can change multiple pages in one commit. A branch consists of multiple commits. 

1. The terminal will add changes locally in your computer, that you later need to send to gitlab.com.

1. You can add changes directly into your computer files after you tell the terminal: “git pull NAME OF DOC”, and then you can send those changes to GitLab through the terminal. (changes like adding files, changing names, adding pictures to files, etc)
