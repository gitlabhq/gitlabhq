((global) => {
  class FilteredSearchManager {
    constructor() {
      this.canDeleteTokenIfExists = false;
      this.bindEvents();
      this.renderDefaultDropdown(document.querySelector('#filter-dropdown'));
    }

    bindEvents() {
      const input = document.querySelector('.filtered-search');

      input.addEventListener('focus', this.toggleContainerHighlight);
      input.addEventListener('blur', this.toggleContainerHighlight);
      input.addEventListener('input', gl.Tokenizer.checkTokens);
      input.addEventListener('keyup', this.inputKeyup.bind(this));
      input.addEventListener('keydown', this.inputKeydown.bind(this));
    }

    toggleContainerHighlight(event) {
      const container = document.querySelector('.filtered-search-container');
      container.classList.toggle('focus');
    }

    inputKeydown(event) {
      const fragmentList = event.target.parentNode.parentNode;
      if (event.key === 'Backspace' && event.target.value === '' && fragmentList.childElementCount > 1) {
        this.canDeleteTokenIfExists = true;
      } else {
        this.canDeleteTokenIfExists = false;
      }

      if (event.key === 'Enter') {
        this.search();
        event.stopPropagation();
        event.preventDefault();
      }
    }

    inputKeyup(event) {
      if (this.canDeleteTokenIfExists) {
        gl.Tokenizer.deleteToken(event.target);
      }

      const fragmentList = event.target.parentNode.parentNode;
      if (fragmentList.childElementCount === 1) {
        event.target.placeholder = 'Search or filter results...';
      }
    }

    renderDefaultDropdown(filterDropdown) {
      filterDropdown.innerHTML = `
        <li>
          <i class="fa fa-search"></i>
          <span>Keep typing and press Enter</span>
        </li>
        <li>
          <i class="fa fa-pencil"></i>
          <span>author: &lt;author&gt;</span>
        </li>
        <li>
          <i class="fa fa-user"></i>
          <span>assignee: &lt;assignee&gt;</span>
        </li>
        <li>
          <i class="fa fa-clock-o"></i>
          <span>milestone: &lt;milestone&gt;</span>
        </li>
        <li>
          <i class="fa fa-tag"></i>
          <span>label: &lt;label&gt;</span>
        </li>
      `;
    }

    search() {
      console.log('search');
    }
  }

  global.FilteredSearchManager = FilteredSearchManager;
})(window.gl || (window.gl = {}));
