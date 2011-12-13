var Loader = { 
  img_src: "/assets/ajax-loader.gif", 

  html: 
    function(width) { 
      img = $("<img>");
      img.attr("width", width);
      img.attr("src", this.img_src);
      return img;
    }
}
