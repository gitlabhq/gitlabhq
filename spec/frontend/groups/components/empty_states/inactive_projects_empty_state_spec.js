import { GlEmptyState } from '@gitlab/ui';

import { mountExtended } from 'helpers/vue_test_utils_helper';
import InactiveProjectsEmptyState from '~/groups/components/empty_states/inactive_projects_empty_state.vue';

let wrapper;

const defaultProvide = {
  emptyProjectsIllustration: '/assets/llustrations/empty-state/empty-projects-md.svg',
};

const createComponent = () => {
  wrapper = mountExtended(InactiveProjectsEmptyState, {
    provide: defaultProvide,
  });
};

describe('InactiveProjectsEmptyState', () => {
  it('renders empty state', () => {
    createComponent();

    expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
      title: InactiveProjectsEmptyState.i18n.title,
      svgPath: defaultProvide.emptyProjectsIllustration,
    });
  });
});
