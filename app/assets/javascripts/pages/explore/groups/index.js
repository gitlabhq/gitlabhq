import initGroupsList from '~/groups';
import Landing from '~/groups/landing';

function exploreGroups() {
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
