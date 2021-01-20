Object.defineProperty(global.HTMLImageElement.prototype, 'src', {
  get() {
    return this.$_jest_src || this.getAttribute('src');
  },
  set(val) {
    this.$_jest_src = val;

    if (this.onload) {
      this.onload();
    }
  },
});
