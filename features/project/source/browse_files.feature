Feature: Project Source Browse Files
  Background:
    Given I sign in as a user
    And I own project "Shop"
    Given I visit project source page

  Scenario: I browse files from master branch
    Then I should see files from repository

  Scenario: I browse files for specific ref
    Given I visit project source page for "6d39438"
    Then I should see files from repository for "6d39438"

  Scenario: I browse file content
    Given I click on ".gitignore" file in repo
    Then I should see its content

  Scenario: I browse raw file
    Given I visit blob file from repo
    And I click link "Raw"
    Then I should see raw file content

  Scenario: I can create file
    Given I click on "New file" link in repo
    Then I can see new file page

  Scenario: I can create file when I don't have write access
    Given I don't have write access
    And I click on "New file" link in repo
    Then I should see a notice about a new fork having been created
    Then I can see new file page

  @javascript
  Scenario: I can create and commit file
    Given I click on "New file" link in repo
    And I edit code
    And I fill the new file name
    And I fill the commit message
    And I click on "Commit Changes"
    Then I am redirected to the new file
    And I should see its new content

  @javascript
  Scenario: I can create and commit file when I don't have write access
    Given I don't have write access
    And I click on "New file" link in repo
    And I edit code
    And I fill the new file name
    And I fill the commit message
    And I click on "Commit Changes"
    Then I am redirected to the fork's new merge request page
    And I can see the new commit message

  @javascript
  Scenario: I can create and commit file with new lines at the end of file
    Given I click on "New file" link in repo
    And I edit code with new lines at end of file
    And I fill the new file name
    And I fill the commit message
    And I click on "Commit Changes"
    Then I am redirected to the new file
    And I click button "Edit"
    And I should see its content with new lines preserved at end of file

  @javascript
  Scenario: I can create and commit file and specify new branch
    Given I click on "New file" link in repo
    And I edit code
    And I fill the new file name
    And I fill the commit message
    And I fill the new branch name
    And I click on "Commit Changes"
    Then I am redirected to the new merge request page
    And I should see its new content

  @javascript
  Scenario: I can upload file and commit
    Given I click on "Upload file" link in repo
    And I upload a new text file
    And I fill the upload file commit message
    And I fill the new branch name
    And I click on "Upload file"
    Then I can see the new text file
    And I am redirected to the new merge request page
    And I can see the new commit message

  @javascript
  Scenario: I can upload file and commit when I don't have write access
    Given I don't have write access
    And I click on "Upload file" link in repo
    Then I should see a notice about a new fork having been created
    When I click on "Upload file" link in repo
    And I upload a new text file
    And I fill the upload file commit message
    And I click on "Upload file"
    Then I can see the new text file
    And I am redirected to the fork's new merge request page
    And I can see the new commit message

  @javascript
  Scenario: I can replace file and commit
    Given I click on ".gitignore" file in repo
    And I see the ".gitignore"
    And I click on "Replace"
    And I replace it with a text file
    And I fill the replace file commit message
    And I click on "Replace file"
    Then I can see the new text file
    And I can see the replacement commit message

  @javascript
  Scenario: I can replace file and commit when I don't have write access
    Given I don't have write access
    And I click on ".gitignore" file in repo
    And I see the ".gitignore"
    And I click on "Replace"
    Then I should see a notice about a new fork having been created
    When I click on "Replace"
    And I replace it with a text file
    And I fill the replace file commit message
    And I click on "Replace file"
    Then I can see the new text file
    And I am redirected to the fork's new merge request page
    And I can see the replacement commit message

  @javascript
  Scenario: I can create file in empty repo
    Given I own an empty project
    And I visit my empty project page
    And I create bare repo
    When I click on "add a file" link
    And I edit code
    And I fill the new file name
    And I fill the commit message
    And I click on "Commit Changes"
    Then I am redirected to the new file
    And I should see its new content

  @javascript
  Scenario: If I enter an illegal file name I see an error message
    Given I click on "New file" link in repo
    And I fill the new file name with an illegal name
    And I edit code
    And I fill the commit message
    And I click on "Commit changes"
    Then I am on the new file page
    And I see a commit error message

  @javascript
  Scenario: I can create file with a directory name
    Given I click on "New file" link in repo
    And I fill the new file name with a new directory
    And I edit code
    And I fill the commit message
    And I click on "Commit changes"
    Then I am redirected to the new file with directory
    And I should see its new content

  @javascript
  Scenario: I can edit file
    Given I click on ".gitignore" file in repo
    And I click button "Edit"
    Then I can edit code

  @javascript
  Scenario: I can edit file when I don't have write access
    Given I don't have write access
    And I click on ".gitignore" file in repo
    And I click button "Edit"
    Then I should see a notice about a new fork having been created
    And I can edit code

  Scenario: If the file is binary the edit link is hidden
    Given I visit a binary file in the repo
    Then I cannot see the edit button

  @javascript
  Scenario: I can edit and commit file
    Given I click on ".gitignore" file in repo
    And I click button "Edit"
    And I edit code
    And I fill the commit message
    And I click on "Commit Changes"
    Then I am redirected to the ".gitignore"
    And I should see its new content

  @javascript
  Scenario: I can edit and commit file when I don't have write access
    Given I don't have write access
    And I click on ".gitignore" file in repo
    And I click button "Edit"
    And I edit code
    And I fill the commit message
    And I click on "Commit Changes"
    Then I am redirected to the fork's new merge request page
    And I can see the new commit message

  @javascript
  Scenario: I can edit and commit file to new branch
    Given I click on ".gitignore" file in repo
    And I click button "Edit"
    And I edit code
    And I fill the commit message
    And I fill the new branch name
    And I click on "Commit Changes"
    Then I am redirected to the new merge request page
    And I should see its new content

  @javascript  @wip
  Scenario: If I don't change the content of the file I see an error message
    Given I click on ".gitignore" file in repo
    And I click button "edit"
    And I fill the commit message
    And I click on "Commit changes"
    # Test fails because carriage returns are added to the file.
    Then I am on the ".gitignore" edit file page
    And I see a commit error message

  @javascript
  Scenario: I can create directory in repo
    When I click on "New directory" link in repo
    And I fill the new directory name
    And I fill the commit message
    And I fill the new branch name
    And I click on "Create directory"
    Then I am redirected to the new merge request page

  @javascript
  Scenario: I can create directory in repo when I don't have write access
    Given I don't have write access
    When I click on "New directory" link in repo
    Then I should see a notice about a new fork having been created
    When I click on "New directory" link in repo
    And I fill the new directory name
    And I fill the commit message
    And I click on "Create directory"
    Then I am redirected to the fork's new merge request page

  @javascript
  Scenario: I attempt to create an existing directory
    When I click on "New directory" link in repo
    And I fill an existing directory name
    And I fill the commit message
    And I click on "Create directory"
    Then I see "Unable to create directory"
    And I am redirected to the root directory

  @javascript
  Scenario: I can see editing preview
    Given I click on ".gitignore" file in repo
    And I click button "Edit"
    And I edit code
    And I click link "Diff"
    Then I see diff

  @javascript
  Scenario: I can delete file and commit
    Given I click on ".gitignore" file in repo
    And I see the ".gitignore"
    And I click on "Delete"
    And I fill the commit message
    And I click on "Delete file"
    Then I am redirected to the files URL
    And I don't see the ".gitignore"

  @javascript
  Scenario: I can delete file and commit when I don't have write access
    Given I don't have write access
    And I click on ".gitignore" file in repo
    And I see the ".gitignore"
    And I click on "Delete"
    Then I should see a notice about a new fork having been created
    When I click on "Delete"
    And I fill the commit message
    And I click on "Delete file"
    Then I am redirected to the fork's new merge request page
    And I can see the new commit message

  Scenario: I can browse directory with Browse Dir
    Given I click on files directory
    And I click on History link
    Then I see Browse dir link

  Scenario: I can browse file with Browse File
    Given I click on readme file
    And I click on History link
    Then I see Browse file link

  Scenario: I can browse code with Browse Code
    Given I click on History link
    Then I see Browse code link

  # Permalink

  Scenario: I click on the permalink link from a branch ref
    Given I click on ".gitignore" file in repo
    And I click on Permalink
    Then I am redirected to the permalink URL

  Scenario: I don't see the permalink link from a SHA ref
    Given I visit project source page for "6d394385cf567f80a8fd85055db1ab4c5295806f"
    And I click on ".gitignore" file in repo
    Then I don't see the permalink link

  @javascript
  Scenario: I browse code with single quotes in the ref
    Given I switch ref to 'test'
    And I see the ref 'test' has been selected
    And I visit the 'test' tree
    Then I see the commit data

  @javascript
  Scenario: I browse code with a leading dot in the directory
    Given I switch ref to fix
    And I visit the fix tree
    Then I see the commit data for a directory with a leading dot

  Scenario: I browse LFS object
    Given I click on "files/lfs/lfs_object.iso" file in repo
    Then I should see download link and object size
    And I should not see lfs pointer details
    And I should see buttons for allowed commands

  @javascript
  Scenario: I preview an SVG file
    Given I click on "Upload file" link in repo
    And I upload a new SVG file
    And I fill the upload file commit message
    And I fill the new branch name
    And I click on "Upload file"
    Given I visit the SVG file
    Then I can see the new rendered SVG image
