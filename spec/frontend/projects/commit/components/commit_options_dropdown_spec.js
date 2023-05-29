import { mountExtended } from 'helpers/vue_test_utils_helper';
import CommitOptionsDropdown from '~/projects/commit/components/commit_options_dropdown.vue';
import { OPEN_REVERT_MODAL, OPEN_CHERRY_PICK_MODAL } from '~/projects/commit/constants';
import eventHub from '~/projects/commit/event_hub';

describe('BranchesDropdown', () => {
  let wrapper;
  const provide = {
    newProjectTagPath: '_new_project_tag_path_',
    emailPatchesPath: '_email_patches_path_',
    plainDiffPath: '_plain_diff_path_',
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(CommitOptionsDropdown, {
      provide,
      propsData: {
        canRevert: true,
        canCherryPick: true,
        canTag: true,
        canEmailPatches: true,
        ...props,
      },
    });
  };

  const findRevertLink = () => wrapper.findByTestId('revert-link');
  const findCherryPickLink = () => wrapper.findByTestId('cherry-pick-link');
  const findTagItem = () => wrapper.findByTestId('tag-link');
  const findEmailPatchesItem = () => wrapper.findByTestId('email-patches-link');
  const findPlainDiffItem = () => wrapper.findByTestId('plain-diff-link');

  describe('Everything enabled', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has expected dropdown button text', () => {
      expect(wrapper.findByTestId('base-dropdown-toggle').text()).toBe('Options');
    });

    it('has expected items', () => {
      expect(
        [
          findRevertLink().exists(),
          findCherryPickLink().exists(),
          findTagItem().exists(),
          findEmailPatchesItem().exists(),
          findPlainDiffItem().exists(),
        ].every((exists) => exists),
      ).toBe(true);
    });

    it('has expected href links', () => {
      expect(findTagItem().attributes('href')).toBe(provide.newProjectTagPath);
      expect(findEmailPatchesItem().attributes('href')).toBe(provide.emailPatchesPath);
      expect(findPlainDiffItem().attributes('href')).toBe(provide.plainDiffPath);
    });
  });

  describe('Different dropdown item permutations', () => {
    it('does not have a revert option', () => {
      createComponent({ canRevert: false });

      expect(findRevertLink().exists()).toBe(false);
    });

    it('does not have a cherry-pick option', () => {
      createComponent({ canCherryPick: false });

      expect(findCherryPickLink().exists()).toBe(false);
    });

    it('does not have a tag option', () => {
      createComponent({ canTag: false });

      expect(findTagItem().exists()).toBe(false);
    });

    it('does not have a patches options', () => {
      createComponent({ canEmailPatches: false });

      expect(findEmailPatchesItem().exists()).toBe(false);
    });

    it('only has the download items', () => {
      createComponent({ canRevert: false, canCherryPick: false, canTag: false });

      expect(findEmailPatchesItem().exists()).toBe(true);
      expect(findPlainDiffItem().exists()).toBe(true);
    });
  });

  describe('Modal triggering', () => {
    let spy;

    beforeEach(() => {
      spy = jest.spyOn(eventHub, '$emit');
      createComponent();
    });

    it('emits openModal for revert', () => {
      findRevertLink().trigger('click');

      expect(spy).toHaveBeenCalledWith(OPEN_REVERT_MODAL);
    });

    it('emits openModal for cherry-pick', () => {
      findCherryPickLink().trigger('click');

      expect(spy).toHaveBeenCalledWith(OPEN_CHERRY_PICK_MODAL);
    });
  });
});
