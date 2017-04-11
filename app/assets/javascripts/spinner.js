class Spinner {
  constructor(renderable) {
    this.renderable = renderable;

    this.container = Spinner.createContainer();
  }

  start() {
    this.renderable.innerHTML = '';
    this.renderable.appendChild(this.container);
  }

  stop() {
    this.container.remove();
  }

  static createContainer() {
    const container = document.createElement('div');
    container.classList.add('loading');

    container.innerHTML = Spinner.TEMPLATE;

    return container;
  }
}

Spinner.TEMPLATE = '<i class="fa fa-spinner fa-spin"></i>';

export default Spinner;
