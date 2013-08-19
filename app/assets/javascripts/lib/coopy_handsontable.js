(function() {

var coopy = null;
if (typeof exports != "undefined") {
    if (typeof exports.Coopy != "undefined") {
	coopy = exports;
    }
}
if (coopy == null) {
    coopy = window.coopy;
}

var diffRenderer = function (instance, td, row, col, prop, value, cellProperties) {

    var className = "";

    var value2 = value;

    // Compute coloration
    var v0 = instance.getDataAtCell(row, 0);
    var v1 = instance.getDataAtCell(0, col);
    var removed_column = false;
    if (v1!=null) {
	if (v1.indexOf("+++")>=0) {
 	    className = 'add';
	} else if (v1.indexOf("---")>=0) {
 	    className = 'remove';
	    removed_column = true;
	} 
    }
    if (v0!=null) {
	if (v0 == "!") {
 	    className = 'spec';
	} else if (v0 == "@@") {
 	    className = 'header';
	} else if (v0 == "+++") {
 	    if (!removed_column) className = 'add';
	} else if (v0 == "---") {
 	    className = 'remove';
	} else if (v0.indexOf("->")>=0) {
	    if (value!=null) {
 		if (!removed_column) {
		    var tokens = v0.split("!");
		    var full = v0;
		    var part = tokens[1];
		    if (part==null) part = full;
		    if (value.indexOf(part)>=0) {
			var name = "modify";
			var div = part;
			// render with utf8 -> symbol
			if (part!=full) {
			    if (value.indexOf(full)>=0) {
				div = full;
				name = 'conflict';
			    }
			}
			value2 = value2.split(div).join(String.fromCharCode(8594));
			className = name;
		    }
		}
	    }
	}
    }

    if (value==null || value=="null") {
	className = className + " null";
	value2 = "";
    }

    if (typeof Handsontable != "undefined") {
	Handsontable.TextCell.renderer.apply(this, [instance,
						    td, row, col, prop,
						    value2,
						    cellProperties]);
    }
    if (className!="") {
	td.className = className;
    }    
    return value2;
}

coopy.diffRenderer = diffRenderer;

})();
