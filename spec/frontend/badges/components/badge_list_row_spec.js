import Vue from 'vue';
import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import { GROUP_BADGE, PROJECT_BADGE } from '~/badges/constants';
import store from '~/badges/store';
import BadgeListRow from '~/badges/components/badge_list_row.vue';
import { createDummyBadge } from '../dummy_badge';

describe('BadgeListRow component', () => {
  const Component = Vue.extend(BadgeListRow);
  let badge;
  let vm;

  beforeEach(() => {
    setFixtures(`
      <div id="delete-badge-modal" class="modal"></div>
      <div id="dummy-element"></div>
    `);
    store.replaceState({
      ...store.state,
      kind: PROJECT_BADGE,
    });
    badge = createDummyBadge();
    vm = mountComponentWithStore(Component, {
      el: '#dummy-element',
      store,
      props: { badge },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders the badge', () => {
    const badgeElement = vm.$el.querySelector('.project-badge');

    expect(badgeElement).not.toBeNull();
    expect(badgeElement.getAttribute('src')).toBe(badge.renderedImageUrl);
  });

  it('renders the badge name', () => {
    expect(vm.$el.innerText).toMatch(badge.name);
  });

  it('renders the badge link', () => {
    expect(vm.$el.innerText).toMatch(badge.linkUrl);
  });

  it('renders the badge kind', () => {
    expect(vm.$el.innerText).toMatch('Project Badge');
  });

  it('shows edit and delete buttons', () => {
    const buttons = vm.$el.querySelectorAll('.table-button-footer button');

    expect(buttons).toHaveLength(2);
    const buttonEditElement = buttons[0];

    expect(buttonEditElement).toBeVisible();
    expect(buttonEditElement).toHaveSpriteIcon('pencil');
    const buttonDeleteElement = buttons[1];

    expect(buttonDeleteElement).toBeVisible();
    expect(buttonDeleteElement).toHaveSpriteIcon('remove');
  });

  it('calls editBadge when clicking then edit button', () => {
    jest.spyOn(vm, 'editBadge').mockImplementation(() => {});

    const editButton = vm.$el.querySelector('.table-button-footer button:first-of-type');
    editButton.click();

    expect(vm.editBadge).toHaveBeenCalled();
  });

  it('calls updateBadgeInModal and shows modal when clicking then delete button', done => {
    jest.spyOn(vm, 'updateBadgeInModal').mockImplementation(() => {});

    const deleteButton = vm.$el.querySelector('.table-button-footer button:last-of-type');
    deleteButton.click();

    Vue.nextTick()
      .then(() => {
        expect(vm.updateBadgeInModal).toHaveBeenCalled();
      })
      .then(done)
      .catch(done.fail);
  });

  describe('for a group badge', () => {
    beforeEach(done => {
      badge.kind = GROUP_BADGE;

      Vue.nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('renders the badge kind', () => {
      expect(vm.$el.innerText).toMatch('Group Badge');
    });

    it('hides edit and delete buttons', () => {
      const buttons = vm.$el.querySelectorAll('.table-button-footer button');

      expect(buttons).toHaveLength(0);
    });
  });
});
