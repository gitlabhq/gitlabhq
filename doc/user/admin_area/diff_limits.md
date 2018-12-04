# Diff limits administration

NOTE: **Note:**
Merge requests and branch comparison views will be affected.

CAUTION: **Caution:**
These settings are currently under experimental state. They'll
increase the resource consumption of your instance and should
be edited mindfully.

1. Access **Admin area > Settings > General**
1. Expand **Diff limits**

### Maximum diff patch size

This is the content size each diff file (patch) is allowed to reach before
it's collapsed, without the possibility of being expanded. A link redirecting
to the blob view will be presented for the patches that surpass this limit.

Patches surpassing 10% of this content size will be automatically collapsed,
but expandable (a link to expand the diff will be presented).
