import Vue from 'vue';

export default class SketchRender {
  constructor(browserId, browserPropsId, files) {
    this.browserId = browserId;
    this.browserPropsId = browserPropsId;
    this.browserStore = {
      currentPageIndex: 0,
      pages: [],
      currentPos: {
        x: 0,
        y: 0,
        width: 0,
        height: 0
      }
    };

    this.files = files;
    if(this.files.hasOwnProperty('document.json')){
      this.files['document.json'].async('string')
       .then(content => this.renderDocument(JSON.parse(content)));
    }

  };

  render() {
    Vue.component('layer', {
      name: 'layer',
      template: 
        `<li class="layer" :class="{artboard: layer._class === 'artboard'}">
          <a href='#' class="expand pull-left" @click.prevent="expand" v-if="layer.layers">
            <span v-if="!expanded">+</span>
            <span v-else>-</span>
          </a>
          <i v-if="layer._class === 'group'" class="fa fa-folder pull-left"></i>
          <i v-if="layer._class === 'text'" class="fa fa-font pull-left"></i>
          <i v-if="layer.isLocked" class="fa fa-lock pull-right"></i>
          <a href='#' @click.prevent="layerSelected(layer)">{{layer.name}}</a>
          <ul v-if="layer.layers" v-show="expanded">
            <layer v-for="layer in layer.layers" @layerselected="layerSelected" :key="layer.do_objectID" :layer="layer"></layer>
          </ul>
        </li>`,
      
      props: {
        layer: Object,
      },

      data() {
        return {
          expanded: false
        }
      },

      methods: {
        expand() {
          this.expanded = !this.expanded;
        },

        layerSelected(layer) {
          this.$emit('layerselected', layer);
        }
      }
    });

    this.vue = new Vue({
      el: `#${this.browserId}`,
      data: this.browserStore,
      computed: {
        currentPage() {
          return this.pages.length ? this.pages[this.currentPageIndex] : {name: 'loading', layers: []};
        }
      },

      methods: {
        pageSelected(pageIndex) {
          this.currentPageIndex = pageIndex;
          this.browserStore.currentPos.x = this.browserStore.pages[this.currentPageIndex].frame.x;
          this.browserStore.currentPos.y = this.browserStore.pages[this.currentPageIndex].frame.y;
          this.browserStore.currentPos.width = this.browserStore.pages[this.currentPageIndex].frame.width;
          this.browserStore.currentPos.height = this.browserStore.pages[this.currentPageIndex].frame.height;
        },

        layerSelected(layer) {
          this.currentPos.x = layer.frame.x;
          this.currentPos.y = layer.frame.y;
          this.currentPos.width = layer.frame.width;
          this.currentPos.height = layer.frame.height;
        }
      }
    });

    this.vuePos = new Vue({
      el: `#${this.browserPropsId}`,
      data: this.browserStore
    });
  };

  storePage(pageJSON) {
    if(pageJSON){
      var page = JSON.parse(pageJSON);
      page.isActive = false;
      this.browserStore.pages.push(page);
    }
  };

  renderDocument(documentJSON) {
    var pages = documentJSON.pages.map(page => `${page._ref}.json`);
    this.currentPageIndex = documentJSON.currentPageIndex;
    pages.reduce((seq, page) => {
      return seq.then((e) => {
        this.storePage(e);
        return this.files[page].async('string');
      });
    }, Promise.resolve())
      .then((e) => {
        this.storePage(e)
        this.browserStore.currentPos.x = this.browserStore.pages[this.currentPageIndex].frame.x;
        this.browserStore.currentPos.y = this.browserStore.pages[this.currentPageIndex].frame.y;
      });
  };
};