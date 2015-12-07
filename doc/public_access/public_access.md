# Public access

GitLab allows you to change your projects' visibility in order be accessed
**publicly** or **internally**.

Projects with either of these visibility levels will be listed in the
public access directory (`/public` under your GitLab instance).
Here is the [GitLab.com example](https://gitlab.com/public).

Internal projects will only be available to authenticated users.

## Visibility of projects

### Public projects

Public projects can be cloned **without any** authentication.

They will also be listed on the public access directory (`/public`).

**Any logged in user** will have [Guest](../permissions/permissions)
permissions on the repository.

### Internal projects

Internal projects can be cloned by any logged in user.

They will also be listed on the public access directory (`/public`) for logged
in users.

Any logged in user will have [Guest](../permissions/permissions) permissions on
the repository.

### How to change project visibility

1. Go to your project's **Settings**
1. Change "Visibility Level" to either Public, Internal or Private

## Visibility of users

The public page of a user, located at `/u/username`, is always visible whether
you are logged in or not.

When visiting the public page of a user, you can only see the projects which
you are privileged to.

## Visibility of groups

The public page of a group, located at `/groups/groupname`, is always visible
to everyone.

Logged out users will be able to see the description and the avatar of the
group as well as all public projects belonging to that group.

## Restricting the use of public or internal projects

In the Admin area under **Settings** (`/admin/application_settings`), you can
restrict the use of visibility levels for users when they create a project or a
snippet. This is useful to prevent people exposing their repositories to public
by accident. The restricted visibility settings do not apply to admin users.
