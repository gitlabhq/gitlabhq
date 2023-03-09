import Vue from 'vue';
import Vuex from 'vuex';
import { mount } from '@vue/test-utils';

import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import BadgeListRow from '~/badges/components/badge_list_row.vue';
import { GROUP_BADGE, PROJECT_BADGE } from '~/badges/constants';

import createState from '~/badges/store/state';
import mutations from '~/badges/store/mutations';
import actions from '~/badges/store/actions';

import { createDummyBadge } from '../dummy_badge';

Vue.use(Vuex);

describe('BadgeListRow component', () => {
  let badge;
  let wrapper;
  let mockedActions;

  const createComponent = (kind) => {
    setHTMLFixture(`<div id="delete-badge-modal" class="modal"></div>`);

    mockedActions = Object.fromEntries(Object.keys(actions).map((name) => [name, jest.fn()]));

    const store = new Vuex.Store({
      state: {
        ...createState(),
        kind: PROJECT_BADGE,
      },
      mutations,
      actions: mockedActions,
    });

    badge = createDummyBadge();
    badge.kind = kind;
    wrapper = mount(BadgeListRow, {
      attachTo: document.body,
      store,
      propsData: { badge },
    });
  };

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('for a project badge', () => {
    beforeEach(() => {
      createComponent(PROJECT_BADGE);
    });

    it('renders the badge', () => {
      const badgeImage = wrapper.find('.project-badge');

      expect(badgeImage.exists()).toBe(true);
      expect(badgeImage.attributes('src')).toBe(badge.renderedImageUrl);
    });

    it('renders the badge name', () => {
      expect(wrapper.text()).toMatch(badge.name);
    });

    it('renders the badge link', () => {
      expect(wrapper.text()).toMatch(badge.linkUrl);
    });

    it('renders the badge kind', () => {
      expect(wrapper.text()).toMatch('Project Badge');
    });

    it('shows edit and delete buttons', () => {
      const buttons = wrapper.findAll('.table-button-footer button');

      expect(buttons).toHaveLength(2);
      const editButton = buttons.at(0);

      expect(editButton.isVisible()).toBe(true);
      expect(editButton.element).toHaveSpriteIcon('pencil');

      const deleteButton = buttons.at(1);
      expect(deleteButton.isVisible()).toBe(true);
      expect(deleteButton.element).toHaveSpriteIcon('remove');
    });

    it('calls editBadge when clicking then edit button', async () => {
      const editButton = wrapper.find('.table-button-footer button:first-of-type');

      await editButton.trigger('click');

      expect(mockedActions.editBadge).toHaveBeenCalled();
    });

    it('calls updateBadgeInModal and shows modal when clicking then delete button', async () => {
      const deleteButton = wrapper.find('.table-button-footer button:last-of-type');

      await deleteButton.trigger('click');

      expect(mockedActions.updateBadgeInModal).toHaveBeenCalled();
    });
  });

  describe('for a group badge', () => {
    beforeEach(() => {
      createComponent(GROUP_BADGE);
    });

    it('renders the badge kind', () => {
      expect(wrapper.text()).toMatch('Group Badge');
    });

    it('hides edit and delete buttons', () => {
      const buttons = wrapper.findAll('.table-button-footer button');

      expect(buttons).toHaveLength(0);
    });
  });
});
