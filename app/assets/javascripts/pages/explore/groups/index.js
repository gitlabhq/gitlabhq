import EmptyState from '~/groups/components/empty_states/groups_explore_empty_state.vue';
import initGroupsList from '~/groups';
import Landing from '~/groups/landing';

function exploreGroups() {
  initGroupsList(EmptyState);
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
