//= require vue

(() => {
    Vue.component('geo-clone-dialog', {
        name: 'geo-clone-dialog',
        props: ['title'],
        data: function() {
            return this.$parent.$data
        },
        filters: {
            emptyRepo: function (value) {
                if (!value) return '<clone url for primary repository>'
                return value
            }
        },
        template: `
            <div class="modal" tabindex="99">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <a href="#" data-dismiss="modal" class="close">×</a>
                            <h3>{{title}}</h3>
                        </div>
                        <div class="modal-body">
                            <slot name="body"></slot>
                            <pre class="dark" id="geo-info">
git clone {{cloneUrlSecondary}}
git remote set-url --push origin {{cloneUrlPrimary | emptyRepo}}
                            </pre>
                        </div>
                    </div>
                </div>
            </div>
        `
    });
})(window.gl || (window.gl = {}));
