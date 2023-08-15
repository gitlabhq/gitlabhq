import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlAlert, GlLink, GlLoadingIcon } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import * as transitionModule from '~/vue_shared/components/diff_viewer/utils';
import {
  TRANSITION_ACKNOWLEDGE_ERROR,
  TRANSITION_LOAD_START,
  TRANSITION_LOAD_ERROR,
  TRANSITION_LOAD_SUCCEED,
  STATE_IDLING,
  STATE_LOADING,
} from '~/diffs/constants';
import Renamed from '~/vue_shared/components/diff_viewer/viewers/renamed.vue';

Vue.use(Vuex);

let wrapper;
let store;
let event;

const DIFF_FILE_COMMIT_SHA = 'commitsha';
const DIFF_FILE_SHORT_SHA = 'commitsh';
const DIFF_FILE_VIEW_PATH = `blob/${DIFF_FILE_COMMIT_SHA}/filename.ext`;

const defaultStore = {
  modules: {
    diffs: {
      namespaced: true,
      actions: { switchToFullDiffFromRenamedFile: jest.fn().mockResolvedValue() },
    },
  },
};
const diffFile = {
  content_sha: DIFF_FILE_COMMIT_SHA,
  view_path: DIFF_FILE_VIEW_PATH,
  alternate_viewer: {
    name: 'text',
  },
};
const defaultProps = { diffFile };

function createRenamedComponent({ props = {}, storeArg = defaultStore, deep = false } = {}) {
  store = new Vuex.Store(storeArg);
  const mnt = deep ? mount : shallowMount;

  wrapper = mnt(Renamed, {
    propsData: { ...defaultProps, ...props },
    store,
  });
}

const findErrorAlert = () => wrapper.findComponent(GlAlert);
const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findShowFullDiffBtn = () => wrapper.findComponent(GlLink);
const findPlainText = () => wrapper.find('[test-id="plaintext"]');

describe('Renamed Diff Viewer', () => {
  beforeEach(() => {
    event = {
      preventDefault: jest.fn(),
    };
  });

  describe('when clicking to load full diff', () => {
    beforeEach(() => {
      createRenamedComponent();
    });

    it('shows a loading state', async () => {
      expect(findLoadingIcon().exists()).toBe(false);

      await findShowFullDiffBtn().vm.$emit('click', event);

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('calls the switchToFullDiffFromRenamedFile action when the method is triggered', () => {
      jest.spyOn(store, 'dispatch');

      findShowFullDiffBtn().vm.$emit('click', event);

      expect(store.dispatch).toHaveBeenCalledWith('diffs/switchToFullDiffFromRenamedFile', {
        diffFile,
      });
    });

    it.each`
      after                      | resolvePromise         | resolution
      ${TRANSITION_LOAD_SUCCEED} | ${'mockResolvedValue'} | ${'successful'}
      ${TRANSITION_LOAD_ERROR}   | ${'mockRejectedValue'} | ${'rejected'}
    `(
      'moves through the correct states during a $resolution request',
      async ({ after, resolvePromise }) => {
        jest.spyOn(transitionModule, 'transition');
        store.dispatch = jest.fn()[resolvePromise]();

        expect(transitionModule.transition).not.toHaveBeenCalled();

        findShowFullDiffBtn().vm.$emit('click', event);

        expect(transitionModule.transition).toHaveBeenCalledWith(
          STATE_IDLING,
          TRANSITION_LOAD_START,
        );

        await waitForPromises();

        expect(transitionModule.transition).toHaveBeenCalledTimes(2);
        expect(transitionModule.transition.mock.calls[1]).toEqual([STATE_LOADING, after]);
      },
    );
  });

  describe('clickLink', () => {
    it.each`
      alternateViewer | stops    | handled
      ${'text'}       | ${true}  | ${'should'}
      ${'nottext'}    | ${false} | ${'should not'}
    `(
      'given { alternate_viewer: { name: "$alternateViewer" } }, the click event $handled be handled in the component',
      ({ alternateViewer, stops }) => {
        const props = {
          diffFile: {
            ...diffFile,
            alternate_viewer: { name: alternateViewer },
          },
        };

        createRenamedComponent({
          props,
        });

        store.dispatch = jest.fn().mockResolvedValue();

        findShowFullDiffBtn().vm.$emit('click', event);

        if (stops) {
          expect(event.preventDefault).toHaveBeenCalled();
          expect(store.dispatch).toHaveBeenCalledWith(
            'diffs/switchToFullDiffFromRenamedFile',
            props,
          );
        } else {
          expect(event.preventDefault).not.toHaveBeenCalled();
          expect(store.dispatch).not.toHaveBeenCalled();
        }
      },
    );
  });

  describe('dismissError', () => {
    beforeEach(() => {
      createRenamedComponent({ props: { diffFile } });
    });

    it(`transitions the component with "${TRANSITION_ACKNOWLEDGE_ERROR}"`, () => {
      jest.spyOn(transitionModule, 'transition');

      expect(transitionModule.transition).not.toHaveBeenCalled();

      findErrorAlert().vm.$emit('dismiss');

      expect(transitionModule.transition).toHaveBeenCalledWith(
        expect.stringContaining(''),
        TRANSITION_ACKNOWLEDGE_ERROR,
      );
    });
  });

  describe('output', () => {
    it.each`
      altViewer    | nameDisplay
      ${'text'}    | ${'"text"'}
      ${'nottext'} | ${'"nottext"'}
      ${undefined} | ${undefined}
      ${null}      | ${null}
    `(
      'with { alternate_viewer: { name: $nameDisplay } }, renders the component',
      ({ altViewer }) => {
        createRenamedComponent({
          props: {
            diffFile: {
              ...diffFile,
              alternate_viewer: {
                ...diffFile.alternate_viewer,
                name: altViewer,
              },
            },
          },
        });

        expect(findPlainText().text()).toBe('File renamed with no changes.');
      },
    );

    it.each`
      altType      | linkText
      ${'text'}    | ${'Show file contents'}
      ${'nottext'} | ${`View file @ ${DIFF_FILE_SHORT_SHA}`}
    `(
      'includes a link to the full file for alternate viewer type "$altType"',
      ({ altType, linkText }) => {
        const file = { ...diffFile };

        file.alternate_viewer.name = altType;
        createRenamedComponent({
          deep: true,
          props: { diffFile: file },
        });

        const link = findShowFullDiffBtn();

        expect(link.text()).toBe(linkText);
        expect(link.attributes('href')).toBe(DIFF_FILE_VIEW_PATH);
      },
    );
  });
});
