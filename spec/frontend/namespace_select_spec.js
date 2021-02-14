import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import NamespaceSelect from '~/namespace_select';

jest.mock('~/deprecated_jquery_dropdown');

describe('NamespaceSelect', () => {
  it('initializes deprecatedJQueryDropdown', () => {
    const dropdown = document.createElement('div');

    // eslint-disable-next-line no-new
    new NamespaceSelect({ dropdown });

    expect(initDeprecatedJQueryDropdown).toHaveBeenCalled();
  });

  describe('as input', () => {
    let deprecatedJQueryDropdownOptions;

    beforeEach(() => {
      const dropdown = document.createElement('div');
      // eslint-disable-next-line no-new
      new NamespaceSelect({ dropdown });
      [[, deprecatedJQueryDropdownOptions]] = initDeprecatedJQueryDropdown.mock.calls;
    });

    it('prevents click events', () => {
      const dummyEvent = new Event('dummy');
      jest.spyOn(dummyEvent, 'preventDefault').mockImplementation(() => {});

      // expect(foo).toContain('test');
      deprecatedJQueryDropdownOptions.clicked({ e: dummyEvent });

      expect(dummyEvent.preventDefault).toHaveBeenCalled();
    });
  });

  describe('as filter', () => {
    let deprecatedJQueryDropdownOptions;

    beforeEach(() => {
      const dropdown = document.createElement('div');
      dropdown.dataset.isFilter = 'true';
      // eslint-disable-next-line no-new
      new NamespaceSelect({ dropdown });
      [[, deprecatedJQueryDropdownOptions]] = initDeprecatedJQueryDropdown.mock.calls;
    });

    it('does not prevent click events', () => {
      const dummyEvent = new Event('dummy');
      jest.spyOn(dummyEvent, 'preventDefault').mockImplementation(() => {});

      deprecatedJQueryDropdownOptions.clicked({ e: dummyEvent });

      expect(dummyEvent.preventDefault).not.toHaveBeenCalled();
    });

    it('sets URL of dropdown items', () => {
      const dummyNamespace = { id: 'eal' };

      const itemUrl = deprecatedJQueryDropdownOptions.url(dummyNamespace);

      expect(itemUrl).toContain(`namespace_id=${dummyNamespace.id}`);
    });
  });
});
