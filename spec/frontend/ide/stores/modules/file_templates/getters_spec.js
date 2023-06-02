import { leftSidebarViews } from '~/ide/constants';
import * as getters from '~/ide/stores/modules/file_templates/getters';
import createState from '~/ide/stores/state';

describe('IDE file templates getters', () => {
  describe('templateTypes', () => {
    it('returns list of template types', () => {
      expect(getters.templateTypes().length).toBe(4);
    });
  });

  describe('showFileTemplatesBar', () => {
    let rootState;

    beforeEach(() => {
      rootState = createState();
    });

    it('returns true if template is found and currentActivityView is edit', () => {
      rootState.currentActivityView = leftSidebarViews.edit.name;

      expect(
        getters.showFileTemplatesBar(
          null,
          {
            templateTypes: getters.templateTypes(),
          },
          rootState,
        )('LICENSE'),
      ).toBe(true);
    });

    it('returns false if template is found and currentActivityView is not edit', () => {
      rootState.currentActivityView = leftSidebarViews.commit.name;

      expect(
        getters.showFileTemplatesBar(
          null,
          {
            templateTypes: getters.templateTypes(),
          },
          rootState,
        )('LICENSE'),
      ).toBe(false);
    });

    it('returns undefined if not found', () => {
      expect(
        getters.showFileTemplatesBar(
          null,
          {
            templateTypes: getters.templateTypes(),
          },
          rootState,
        )('test'),
      ).toBe(undefined);
    });
  });
});
