import initGroupsList from '~/groups';
import GroupsList from '~/groups/groups_list';
import Landing from '~/groups/landing';

function exploreGroups() {
  new GroupsList(); // eslint-disable-line no-new
  initGroupsList();
  const landingElement = document.querySelector('.js-explore-groups-landing');
  if (!landingElement) return;
  const exploreGroupsLanding = new Landing(
    landingElement,
    landingElement.querySelector('.dismiss-button'),
    'explore_groups_landing_dismissed',
  );
  exploreGroupsLanding.toggle();
}

exploreGroups();
