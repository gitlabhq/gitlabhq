import { shallowMount } from '@vue/test-utils';
import SidebarReviewersInputs from '~/sidebar/components/reviewers/sidebar_reviewers_inputs.vue';
import { state } from '~/sidebar/components/reviewers/sidebar_reviewers.vue';

let wrapper;

function factory() {
  wrapper = shallowMount(SidebarReviewersInputs);
}

describe('Sidebar reviewers inputs component', () => {
  it('renders hidden input', () => {
    state.issuable.reviewers = {
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

    expect(wrapper.findAll('input[type="hidden"]').length).toBe(2);
  });
});
