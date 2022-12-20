import { GlEmptyState } from '@gitlab/ui';

import { mountExtended } from 'helpers/vue_test_utils_helper';
import ArchivedProjectsEmptyState from '~/groups/components/empty_states/archived_projects_empty_state.vue';

let wrapper;

const defaultProvide = {
  newProjectIllustration: '/assets/illustrations/project-create-new-sm.svg',
};

const createComponent = () => {
  wrapper = mountExtended(ArchivedProjectsEmptyState, {
    provide: defaultProvide,
  });
};

describe('ArchivedProjectsEmptyState', () => {
  it('renders empty state', () => {
    createComponent();

    expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
      title: ArchivedProjectsEmptyState.i18n.title,
      svgPath: defaultProvide.newProjectIllustration,
    });
  });
});
