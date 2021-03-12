import $ from 'jquery';
import ProjectSelectComboButton from '~/project_select_combo_button';

const fixturePath = 'static/project_select_combo_button.html';

describe('Project Select Combo Button', () => {
  let testContext;

  beforeEach(() => {
    testContext = {};
  });

  beforeEach(() => {
    testContext.defaults = {
      label: 'Select project to create issue',
      groupId: 12345,
      projectMeta: {
        name: 'My Cool Project',
        url: 'http://mycoolproject.com',
      },
      newProjectMeta: {
        name: 'My Other Cool Project',
        url: 'http://myothercoolproject.com',
      },
      localStorageKey: 'group-12345-new-issue-recent-project',
      relativePath: 'issues/new',
    };

    loadFixtures(fixturePath);

    testContext.newItemBtn = document.querySelector('.new-project-item-link');
    testContext.projectSelectInput = document.querySelector('.project-item-select');
  });

  describe('on page load when localStorage is empty', () => {
    beforeEach(() => {
      testContext.comboButton = new ProjectSelectComboButton(testContext.projectSelectInput);
    });

    it('newItemBtn href is null', () => {
      expect(testContext.newItemBtn.getAttribute('href')).toBe('');
    });

    it('newItemBtn text is the plain default label', () => {
      expect(testContext.newItemBtn.textContent).toBe(testContext.defaults.label);
    });
  });

  describe('on page load when localStorage is filled', () => {
    beforeEach(() => {
      window.localStorage.setItem(
        testContext.defaults.localStorageKey,
        JSON.stringify(testContext.defaults.projectMeta),
      );
      testContext.comboButton = new ProjectSelectComboButton(testContext.projectSelectInput);
    });

    it('newItemBtn href is correctly set', () => {
      expect(testContext.newItemBtn.getAttribute('href')).toBe(
        testContext.defaults.projectMeta.url,
      );
    });

    it('newItemBtn text is the cached label', () => {
      expect(testContext.newItemBtn.textContent).toBe(
        `New issue in ${testContext.defaults.projectMeta.name}`,
      );
    });

    afterEach(() => {
      window.localStorage.clear();
    });
  });

  describe('after selecting a new project', () => {
    beforeEach(() => {
      testContext.comboButton = new ProjectSelectComboButton(testContext.projectSelectInput);

      // mock the effect of selecting an item from the projects dropdown (select2)
      $('.project-item-select')
        .val(JSON.stringify(testContext.defaults.newProjectMeta))
        .trigger('change');
    });

    it('newItemBtn href is correctly set', () => {
      expect(testContext.newItemBtn.getAttribute('href')).toBe(
        'http://myothercoolproject.com/issues/new',
      );
    });

    it('newItemBtn text is the selected project label', () => {
      expect(testContext.newItemBtn.textContent).toBe(
        `New issue in ${testContext.defaults.newProjectMeta.name}`,
      );
    });

    afterEach(() => {
      window.localStorage.clear();
    });
  });

  describe('deriveTextVariants', () => {
    beforeEach(() => {
      testContext.mockExecutionContext = {
        resourceType: '',
        resourceLabel: '',
      };

      testContext.comboButton = new ProjectSelectComboButton(testContext.projectSelectInput);

      testContext.method = testContext.comboButton.deriveTextVariants.bind(
        testContext.mockExecutionContext,
      );
    });

    it('correctly derives test variants for merge requests', () => {
      testContext.mockExecutionContext.resourceType = 'merge_requests';
      testContext.mockExecutionContext.resourceLabel = 'New merge request';

      const returnedVariants = testContext.method();

      expect(returnedVariants.localStorageItemType).toBe('new-merge-request');
      expect(returnedVariants.defaultTextPrefix).toBe('New merge request');
      expect(returnedVariants.presetTextSuffix).toBe('merge request');
    });

    it('correctly derives text variants for issues', () => {
      testContext.mockExecutionContext.resourceType = 'issues';
      testContext.mockExecutionContext.resourceLabel = 'New issue';

      const returnedVariants = testContext.method();

      expect(returnedVariants.localStorageItemType).toBe('new-issue');
      expect(returnedVariants.defaultTextPrefix).toBe('New issue');
      expect(returnedVariants.presetTextSuffix).toBe('issue');
    });
  });
});
