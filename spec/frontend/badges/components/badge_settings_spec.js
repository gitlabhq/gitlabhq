import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import BadgeList from '~/badges/components/badge_list.vue';
import BadgeListRow from '~/badges/components/badge_list_row.vue';
import BadgeSettings from '~/badges/components/badge_settings.vue';
import store from '~/badges/store';
import { createDummyBadge } from '../dummy_badge';

Vue.use(Vuex);

describe('BadgeSettings component', () => {
  let wrapper;
  const badge = createDummyBadge();

  const createComponent = (isEditing = false) => {
    store.state.badges = [badge];
    store.state.kind = 'project';
    store.state.isEditing = isEditing;

    wrapper = shallowMount(BadgeSettings, {
      store,
      stubs: {
        'badge-list': BadgeList,
        'badge-list-row': BadgeListRow,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('displays modal if button for deleting a badge is clicked', async () => {
    const button = wrapper.find('[data-testid="delete-badge"]');

    button.vm.$emit('click');
    await nextTick();

    const modal = wrapper.findComponent(GlModal);
    expect(modal.isVisible()).toBe(true);
  });

  it('displays a form to add a badge', () => {
    expect(wrapper.find('[data-testid="add-new-badge"]').isVisible()).toBe(true);
  });

  it('displays badge list', () => {
    expect(wrapper.findComponent(BadgeList).isVisible()).toBe(true);
  });

  describe('when editing', () => {
    beforeEach(() => {
      createComponent(true);
    });

    it('displays a form to edit a badge', () => {
      expect(wrapper.find('[data-testid="edit-badge"]').isVisible()).toBe(true);
    });

    it('displays no badge list', () => {
      expect(wrapper.findComponent(BadgeList).isVisible()).toBe(false);
    });
  });
});
