import { shallowMount } from '@vue/test-utils';
import SidebarReviewersInputs from '~/sidebar/components/reviewers/sidebar_reviewers_inputs.vue';
import { sidebarState } from '~/sidebar/sidebar_state';

let wrapper;

function factory() {
  wrapper = shallowMount(SidebarReviewersInputs);
}

describe('Sidebar reviewers inputs component', () => {
  it('renders hidden input', () => {
    sidebarState.issuable.reviewers = {
      nodes: [
        {
          id: 1,
          avatarUrl: '',
          name: 'root',
          username: 'root',
          mergeRequestInteraction: { canMerge: true },
        },
        {
          id: 2,
          avatarUrl: '',
          name: 'root',
          username: 'root',
          mergeRequestInteraction: { canMerge: true },
        },
      ],
    };

    factory();

    expect(wrapper.findAll('input[type="hidden"]')).toHaveLength(2);
  });
});
