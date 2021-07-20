import {
  isInGroupsPage,
  isInProjectPage,
  getGroupSlug,
  getProjectSlug,
} from '~/search_autocomplete_utils';

describe('search_autocomplete_utils', () => {
  let originalBody;

  beforeEach(() => {
    originalBody = document.body;
    document.body = document.createElement('body');
  });

  afterEach(() => {
    document.body = originalBody;
  });

  describe('isInGroupsPage', () => {
    it.each`
      page               | result
      ${'groups:index'}  | ${true}
      ${'groups:show'}   | ${true}
      ${'projects:show'} | ${false}
    `(`returns $result in for page $page`, ({ page, result }) => {
      document.body.dataset.page = page;

      expect(isInGroupsPage()).toBe(result);
    });
  });

  describe('isInProjectPage', () => {
    it.each`
      page                | result
      ${'projects:index'} | ${true}
      ${'projects:show'}  | ${true}
      ${'groups:show'}    | ${false}
    `(`returns $result in for page $page`, ({ page, result }) => {
      document.body.dataset.page = page;

      expect(isInProjectPage()).toBe(result);
    });
  });

  describe('getProjectSlug', () => {
    it('returns null when no project is present or on project page', () => {
      expect(getProjectSlug()).toBe(null);
    });

    it('returns null when not on project page', () => {
      document.body.dataset.project = 'gitlab';

      expect(getProjectSlug()).toBe(null);
    });

    it('returns null when project is missing', () => {
      document.body.dataset.page = 'projects';

      expect(getProjectSlug()).toBe(undefined);
    });

    it('returns project', () => {
      document.body.dataset.page = 'projects';
      document.body.dataset.project = 'gitlab';

      expect(getProjectSlug()).toBe('gitlab');
    });

    it('returns project in edit page', () => {
      document.body.dataset.page = 'projects:edit';
      document.body.dataset.project = 'gitlab';

      expect(getProjectSlug()).toBe('gitlab');
    });
  });

  describe('getGroupSlug', () => {
    it('returns null when no group is present or on group page', () => {
      expect(getGroupSlug()).toBe(null);
    });

    it('returns null when not on group page', () => {
      document.body.dataset.group = 'gitlab-org';

      expect(getGroupSlug()).toBe(null);
    });

    it('returns null when group is missing on groups page', () => {
      document.body.dataset.page = 'groups';

      expect(getGroupSlug()).toBe(undefined);
    });

    it('returns null when group is missing on project page', () => {
      document.body.dataset.page = 'project';

      expect(getGroupSlug()).toBe(null);
    });

    it.each`
      page
      ${'groups'}
      ${'groups:edit'}
      ${'projects'}
      ${'projects:edit'}
    `(`returns group in page $page`, ({ page }) => {
      document.body.dataset.page = page;
      document.body.dataset.group = 'gitlab-org';

      expect(getGroupSlug()).toBe('gitlab-org');
    });
  });
});
