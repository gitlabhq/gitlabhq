import { createTestingPinia } from '@pinia/testing';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';
import { useMainContainer } from '~/pinia/global_stores/main_container';
import { FILE_TREE_BROWSER_VISIBILITY } from '~/repository/constants';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

jest.mock('~/pinia/global_stores/main_container', () => ({ useMainContainer: jest.fn() }));

describe('useFileTreeBrowserVisibility', () => {
  let store;
  let mockMainContainerStore;

  useLocalStorageSpy();

  beforeEach(() => {
    mockMainContainerStore = {
      isCompact: false,
      isIntermediate: false,
      isWide: true,
    };

    useMainContainer.mockReturnValue(mockMainContainerStore);
    createTestingPinia({
      stubActions: false,
    });
    store = useFileTreeBrowserVisibility();
  });

  afterEach(() => {
    localStorage.clear();
    store.resetFileTreeBrowserAllStates();
  });

  describe('getters', () => {
    describe('fileTreeBrowserIsVisible', () => {
      it.each([
        { expanded: true, peek: false, expected: true, description: 'when expanded' },
        { expanded: false, peek: true, expected: true, description: 'when peek is on' },
        { expanded: true, peek: true, expected: true, description: 'when both are true' },
        { expanded: false, peek: false, expected: false, description: 'when both are false' },
      ])('returns $expected $description', ({ expanded, peek, expected }) => {
        store.fileTreeBrowserIsExpanded = expanded;
        store.fileTreeBrowserIsPeekOn = peek;

        expect(store.fileTreeBrowserIsVisible).toBe(expected);
      });
    });
  });

  describe('setFileTreeBrowserIsExpanded', () => {
    it.each([
      { value: true, description: 'expanded', expectedStorage: 'true' },
      { value: false, description: 'collapsed', expectedStorage: 'false' },
    ])(
      'updates state and saves to localStorage when $description',
      ({ value, expectedStorage }) => {
        store.setFileTreeBrowserIsExpanded(value);

        expect(store.fileTreeBrowserIsExpanded).toBe(value);
        expect(localStorage.setItem).toHaveBeenCalledWith(
          FILE_TREE_BROWSER_VISIBILITY,
          expectedStorage,
        );
      },
    );

    it('handles localStorage errors gracefully', () => {
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
      localStorage.setItem.mockImplementation(() => {
        throw new Error('localStorage error');
      });

      expect(() => store.setFileTreeBrowserIsExpanded(true)).not.toThrow();
      expect(store.fileTreeBrowserIsExpanded).toBe(true);

      consoleSpy.mockRestore();
    });
  });

  describe('resetFileTreeBrowserAllStates', () => {
    it('resets all states to false', () => {
      store.fileTreeBrowserIsExpanded = true;
      store.fileTreeBrowserIsPeekOn = true;

      store.resetFileTreeBrowserAllStates();

      expect(store.fileTreeBrowserIsExpanded).toBe(false);
      expect(store.fileTreeBrowserIsPeekOn).toBe(false);
    });
  });

  describe('loadFileTreeBrowserExpandedFromLocalStorage', () => {
    it.each([
      { storageValue: 'true', expected: true, description: 'true value' },
      { storageValue: 'false', expected: false, description: 'false value' },
    ])('loads $description from localStorage', ({ storageValue, expected }) => {
      localStorage.setItem(FILE_TREE_BROWSER_VISIBILITY, storageValue);

      store.loadFileTreeBrowserExpandedFromLocalStorage();

      expect(store.fileTreeBrowserIsExpanded).toBe(expected);
    });

    it('does nothing when localStorage is empty', () => {
      store.loadFileTreeBrowserExpandedFromLocalStorage();

      expect(store.fileTreeBrowserIsExpanded).toBe(false);
    });

    it('handles localStorage errors gracefully', () => {
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
      localStorage.getItem.mockImplementation(() => {
        throw new Error('localStorage error');
      });

      expect(() => store.loadFileTreeBrowserExpandedFromLocalStorage()).not.toThrow();
      expect(store.fileTreeBrowserIsExpanded).toBe(false);

      consoleSpy.mockRestore();
    });
  });

  describe('handleFileTreeBrowserToggleClick', () => {
    it.each`
      isIntermediateSize | initialState                        | expectedResult
      ${true}            | ${{ peek: false, expanded: false }} | ${{ peek: true, expanded: false }}
      ${false}           | ${{ peek: false, expanded: false }} | ${{ peek: false, expanded: true }}
    `(
      'on $viewport viewport: toggles from $initialState to $expectedResult',
      ({ isIntermediateSize, initialState, expectedResult }) => {
        mockMainContainerStore.isIntermediate = isIntermediateSize;
        store.fileTreeBrowserIsPeekOn = initialState.peek;
        store.fileTreeBrowserIsExpanded = initialState.expanded;

        store.handleFileTreeBrowserToggleClick();

        expect(store.fileTreeBrowserIsPeekOn).toBe(expectedResult.peek);
        expect(store.fileTreeBrowserIsExpanded).toBe(expectedResult.expanded);
      },
    );
  });

  describe('initializeFileTreeBrowser', () => {
    it.each`
      isWideSize | localStorageValue | expectedExpanded | description
      ${true}    | ${'true'}         | ${true}          | ${'loads from localStorage on wide viewport'}
      ${false}   | ${'true'}         | ${false}         | ${'does not load from localStorage on non-wide viewport'}
    `('$description', ({ isWideSize, localStorageValue, expectedExpanded }) => {
      localStorage.setItem(FILE_TREE_BROWSER_VISIBILITY, localStorageValue);
      mockMainContainerStore.isWide = isWideSize;

      store.initializeFileTreeBrowser();

      expect(store.fileTreeBrowserIsExpanded).toBe(expectedExpanded);
    });
  });

  describe('focus restoration', () => {
    describe('shouldRestoreFocusToToggle state', () => {
      it('initializes to false', () => {
        expect(store.shouldRestoreFocusToToggle).toBe(false);
      });
    });

    describe('handleFileTreeBrowserToggleClick', () => {
      it('sets shouldRestoreFocusToToggle to true when toggling', () => {
        store.handleFileTreeBrowserToggleClick();

        expect(store.shouldRestoreFocusToToggle).toBe(true);
      });

      it('sets flag before toggling expanded state', () => {
        const initialExpanded = store.fileTreeBrowserIsExpanded;

        store.handleFileTreeBrowserToggleClick();

        // Flag should be set
        expect(store.shouldRestoreFocusToToggle).toBe(true);
        // State should have toggled
        expect(store.fileTreeBrowserIsExpanded).toBe(!initialExpanded);
      });
    });

    describe('clearRestoreFocusFlag', () => {
      it('sets shouldRestoreFocusToToggle to false', () => {
        store.shouldRestoreFocusToToggle = true;

        store.clearRestoreFocusFlag();

        expect(store.shouldRestoreFocusToToggle).toBe(false);
      });
    });
  });
});
