import initLDAPGroupsSelect from 'ee/ldap_groups_select';
import initLDAPGroupLinks from 'ee/groups/ldap_group_links';

document.addEventListener('DOMContentLoaded', () => {
  initLDAPGroupsSelect();
  initLDAPGroupLinks();
});
