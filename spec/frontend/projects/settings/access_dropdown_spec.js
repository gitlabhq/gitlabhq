import $ from 'jquery';
import AccessDropdown from '~/projects/settings/access_dropdown';
import { LEVEL_TYPES } from '~/projects/settings/constants';

describe('AccessDropdown', () => {
  const defaultLabel = 'dummy default label';
  let dropdown;

  beforeEach(() => {
    setFixtures(`
      <div id="dummy-dropdown">
        <span class="dropdown-toggle-text"></span>
      </div>
    `);
    const $dropdown = $('#dummy-dropdown');
    $dropdown.data('defaultLabel', defaultLabel);
    const options = {
      $dropdown,
      accessLevelsData: {
        roles: [
          {
            id: 42,
            text: 'Dummy Role',
          },
        ],
      },
    };
    dropdown = new AccessDropdown(options);
  });

  describe('toggleLabel', () => {
    let $dropdownToggleText;
    const dummyItems = [
      { type: LEVEL_TYPES.ROLE, access_level: 42 },
      { type: LEVEL_TYPES.USER },
      { type: LEVEL_TYPES.USER },
      { type: LEVEL_TYPES.GROUP },
      { type: LEVEL_TYPES.GROUP },
      { type: LEVEL_TYPES.GROUP },
      { type: LEVEL_TYPES.DEPLOY_KEY },
      { type: LEVEL_TYPES.DEPLOY_KEY },
      { type: LEVEL_TYPES.DEPLOY_KEY },
    ];

    beforeEach(() => {
      $dropdownToggleText = $('.dropdown-toggle-text');
    });

    it('displays number of items', () => {
      dropdown.setSelectedItems(dummyItems);
      $dropdownToggleText.addClass('is-default');

      const label = dropdown.toggleLabel();

      expect(label).toBe('1 role, 2 users, 3 deploy keys, 3 groups');
      expect($dropdownToggleText).not.toHaveClass('is-default');
    });

    describe('without selected items', () => {
      beforeEach(() => {
        dropdown.setSelectedItems([]);
      });

      it('falls back to default label', () => {
        const label = dropdown.toggleLabel();

        expect(label).toBe(defaultLabel);
        expect($dropdownToggleText).toHaveClass('is-default');
      });
    });

    describe('with only role', () => {
      beforeEach(() => {
        dropdown.setSelectedItems(dummyItems.filter((item) => item.type === LEVEL_TYPES.ROLE));
        $dropdownToggleText.addClass('is-default');
      });

      it('displays the role name', () => {
        const label = dropdown.toggleLabel();

        expect(label).toBe('Dummy Role');
        expect($dropdownToggleText).not.toHaveClass('is-default');
      });
    });

    describe('with only users', () => {
      beforeEach(() => {
        dropdown.setSelectedItems(dummyItems.filter((item) => item.type === LEVEL_TYPES.USER));
        $dropdownToggleText.addClass('is-default');
      });

      it('displays number of users', () => {
        const label = dropdown.toggleLabel();

        expect(label).toBe('2 users');
        expect($dropdownToggleText).not.toHaveClass('is-default');
      });
    });

    describe('with only groups', () => {
      beforeEach(() => {
        dropdown.setSelectedItems(dummyItems.filter((item) => item.type === LEVEL_TYPES.GROUP));
        $dropdownToggleText.addClass('is-default');
      });

      it('displays number of groups', () => {
        const label = dropdown.toggleLabel();

        expect(label).toBe('3 groups');
        expect($dropdownToggleText).not.toHaveClass('is-default');
      });
    });

    describe('with users and groups', () => {
      beforeEach(() => {
        const selectedTypes = [LEVEL_TYPES.GROUP, LEVEL_TYPES.USER];
        dropdown.setSelectedItems(dummyItems.filter((item) => selectedTypes.includes(item.type)));
        $dropdownToggleText.addClass('is-default');
      });

      it('displays number of groups', () => {
        const label = dropdown.toggleLabel();

        expect(label).toBe('2 users, 3 groups');
        expect($dropdownToggleText).not.toHaveClass('is-default');
      });
    });

    describe('with users and deploy keys', () => {
      beforeEach(() => {
        const selectedTypes = [LEVEL_TYPES.DEPLOY_KEY, LEVEL_TYPES.USER];
        dropdown.setSelectedItems(dummyItems.filter((item) => selectedTypes.includes(item.type)));
        $dropdownToggleText.addClass('is-default');
      });

      it('displays number of deploy keys', () => {
        const label = dropdown.toggleLabel();

        expect(label).toBe('2 users, 3 deploy keys');
        expect($dropdownToggleText).not.toHaveClass('is-default');
      });
    });
  });

  describe('userRowHtml', () => {
    it('escapes users name', () => {
      const user = {
        avatar_url: '',
        name: '<img src=x onerror=alert(document.domain)>',
        username: 'test',
      };
      const template = dropdown.userRowHtml(user);

      expect(template).not.toContain(user.name);
    });
  });
});
