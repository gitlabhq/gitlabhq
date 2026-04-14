import renderStickyTableHeaders from '~/behaviors/markdown/render_table_headers';

describe('renderStickyTableHeaders', () => {
  let table;

  beforeEach(() => {
    window.gon = { features: { editorStickyTableHeaders: true } };
    table = document.createElement('table');
    document.body.appendChild(table);
  });

  afterEach(() => {
    document.body.innerHTML = '';
    delete window.gon;
  });

  describe('when feature flag is disabled', () => {
    it('does not wrap tables when feature flag is false', () => {
      window.gon.features.editorStickyTableHeaders = false;

      renderStickyTableHeaders([table]);

      expect(table.parentNode).toBe(document.body);
      expect(document.querySelector('[data-sticky-header]')).toBeNull();
    });
  });

  describe('when feature flag is enabled', () => {
    it('wraps table in a sticky header wrapper', () => {
      renderStickyTableHeaders([table]);

      const wrapper = document.querySelector('[data-sticky-header]');
      expect(wrapper).not.toBeNull();
      expect(wrapper.contains(table)).toBe(true);
    });

    it('processes multiple tables', () => {
      const table2 = document.createElement('table');
      document.body.appendChild(table2);

      renderStickyTableHeaders([table, table2]);

      const wrappers = document.querySelectorAll('[data-sticky-header]');
      expect(wrappers).toHaveLength(2);
      expect(wrappers[0].contains(table)).toBe(true);
      expect(wrappers[1].contains(table2)).toBe(true);
    });
  });

  describe('when table is already wrapped', () => {
    it('does not wrap table with data-sticky-header attribute', () => {
      const existingWrapper = document.createElement('div');
      existingWrapper.dataset.stickyHeader = '';
      document.body.appendChild(existingWrapper);
      existingWrapper.appendChild(table);

      renderStickyTableHeaders([table]);

      const wrappers = document.querySelectorAll('[data-sticky-header]');
      expect(wrappers).toHaveLength(1);
      expect(wrappers[0]).toBe(existingWrapper);
    });

    it.each`
      className
      ${'gl-table-shadow'}
      ${'ProseMirror'}
      ${'tableWrapper'}
    `('does not wrap table inside .$className', ({ className }) => {
      const existingWrapper = document.createElement('div');
      existingWrapper.classList.add(className);
      document.body.appendChild(existingWrapper);
      existingWrapper.appendChild(table);

      renderStickyTableHeaders([table]);

      expect(document.querySelectorAll('[data-sticky-header]')).toHaveLength(0);
      expect(table.parentNode).toBe(existingWrapper);
    });
  });
});
